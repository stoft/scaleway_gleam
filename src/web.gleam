import dot_env as dot
import dot_env/env
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  dot.load_default()

  let secret_key_base = case env.get_string("SECRET_KEY_BASE") {
    Ok(v) -> v
    Error(_) ->
      "this-is-a-secret-key-that-must-be-at-least-64-characters-long-for-security-purposes"
  }

  let port = case env.get_string("PORT") {
    Ok(p) -> int.parse(p) |> result.unwrap(3000)
    Error(_) -> 3000
  }

  io.println("Starting server on http://localhost:" <> int.to_string(port))
  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(port)
    |> mist.start
  process.sleep_forever()
}

fn handle_request(request: wisp.Request) -> wisp.Response {
  let hanko_api_url = case env.get_string("HANKO_API_URL") {
    Ok(v) -> v
    Error(_) -> ""
  }
  let cookie_name = case env.get_string("HANKO_SESSION_COOKIE_NAME") {
    Ok(v) -> v
    Error(_) -> "hanko"
  }

  case request.path {
    "/" -> hello_world(request)
    "/hello" -> hello_world(request)
    "/login" -> login_page(hanko_api_url)
    "/profile" -> profile_page(hanko_api_url)
    "/api/me" -> me_endpoint(request, hanko_api_url, cookie_name)
    _ -> wisp.not_found()
  }
}

fn hello_world(_request: wisp.Request) -> wisp.Response {
  let html =
    "<!DOCTYPE html>
<html>
<head>
    <title>Hello World - Wisp</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            max-width: 800px; 
            margin: 50px auto; 
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 15px;
            text-align: center;
            backdrop-filter: blur(10px);
        }
        h1 { 
            font-size: 3em; 
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        p { 
            font-size: 1.2em; 
            margin-bottom: 30px;
        }
        .feature-list {
            text-align: left;
            max-width: 400px;
            margin: 0 auto;
        }
        .feature-list li {
            margin: 10px 0;
            padding: 10px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>🌊 Hello from Wisp!</h1>
        <p>This is a simple web application that uses Wisp and Hanko for authentication.</p>
        
        <div class=\"feature-list\">
            <h3>What you've got:</h3>
            <ul>
                <li>✨ Functional web framework</li>
                <li>🚀 Built with Gleam</li>
                <li>🎨 Beautiful styling</li>
                <li>⚡ Fast and lightweight</li>
            </ul>
        </div>
        
        <p>
          <a href=\"/login\" style=\"
            display: inline-block;
            padding: 10px 16px;
            background: rgba(255,255,255,0.2);
            color: white;
            text-decoration: none;
            border-radius: 8px;
          \">Go to Login</a>\n
        </p>
    </div>
</body>
</html>"

  wisp.html_response(html, 200)
}

fn login_page(hanko_api_url: String) -> wisp.Response {
  let html =
    "<!DOCTYPE html>\n"
    <> "<html>\n<head>\n<title>Login</title>\n</head>\n<body>\n"
    <> "<hanko-auth></hanko-auth>\n"
    <> "<script type=\"module\">\n"
    <> "import { register } from 'https://esm.run/@teamhanko/hanko-elements';\n"
    <> "const { hanko } = await register('"
    <> hanko_api_url
    <> "');\n"
    <> "hanko.onSessionCreated(() => { document.location.href = '/profile'; });\n"
    <> "</script>\n"
    <> "</body>\n</html>"

  wisp.html_response(html, 200)
}

fn profile_page(hanko_api_url: String) -> wisp.Response {
  let html =
    "<!DOCTYPE html>\n"
    <> "<html>\n<head>\n<title>Profile</title>\n</head>\n<body>\n"
    <> "<nav><a href=\"#\" id=\"logout-link\">Logout</a></nav>\n"
    <> "<hanko-profile></hanko-profile>\n"
    <> "<script type=\"module\">\n"
    <> "import { register } from 'https://esm.run/@teamhanko/hanko-elements';\n"
    <> "const { hanko } = await register('"
    <> hanko_api_url
    <> "');\n"
    <> "document.getElementById('logout-link').addEventListener('click', (e) => { e.preventDefault(); hanko.user.logout(); });\n"
    <> "hanko.onUserLoggedOut(() => { document.location.href = '/login'; });\n"
    <> "</script>\n"
    <> "</body>\n</html>"

  wisp.html_response(html, 200)
}

fn me_endpoint(
  req: wisp.Request,
  hanko_api_url: String,
  cookie_name: String,
) -> wisp.Response {
  // Extract token from cookie
  let token = request.get_cookies(req) |> list.key_find(cookie_name)
  case token {
    Error(_) -> unauthorized_json()
    Ok(t) -> {
      case validate_hanko_session(hanko_api_url, t) {
        Ok(True) -> wisp.json_response("{\"authenticated\": true}", 200)
        Ok(False) -> unauthorized_json()
        Error(_e) -> unauthorized_json()
      }
    }
  }
}

fn unauthorized_json() -> wisp.Response {
  wisp.json_response("{\"error\": \"unauthorized\"}", 401)
}

fn validate_hanko_session(
  hanko_api_url: String,
  token: String,
) -> Result(Bool, String) {
  // Build request
  let assert Ok(base) = request.to(hanko_api_url <> "/sessions/validate")
  let req =
    base
    |> request.set_method(http.Post)
    |> request.prepend_header("content-type", "application/json")
    |> request.set_body(
      json.object([#("session_token", json.string(token))])
      |> json.to_string,
    )

  case httpc.send(req) {
    Error(_e) -> Error("http_error")
    Ok(resp) ->
      case resp.status == 200 {
        False -> Ok(False)
        True -> {
          let decoder = {
            use valid <- decode.field("is_valid", decode.bool)
            decode.success(valid)
          }
          case json.parse(resp.body, decoder) {
            Ok(valid) -> Ok(valid)
            Error(_) -> Error("invalid_json")
          }
        }
      }
  }
}
