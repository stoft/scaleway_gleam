import gleam/erlang/process
import gleam/io
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  let secret_key_base =
    "this-is-a-secret-key-that-must-be-at-least-64-characters-long-for-security-purposes"

  io.println("Starting server on http://localhost:3000")
  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start
  process.sleep_forever()
}

fn handle_request(request: wisp.Request) -> wisp.Response {
  case request.path {
    "/" -> hello_world(request)
    "/hello" -> hello_world(request)
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
        <p>Welcome to your first Wisp web application!</p>
        
        <div class=\"feature-list\">
            <h3>What you've got:</h3>
            <ul>
                <li>✨ Functional web framework</li>
                <li>🚀 Built with Gleam</li>
                <li>🎨 Beautiful styling</li>
                <li>⚡ Fast and lightweight</li>
            </ul>
        </div>
        
        <p><strong>Server running on:</strong> http://localhost:3000</p>
    </div>
</body>
</html>"

  wisp.html_response(html, 200)
}
