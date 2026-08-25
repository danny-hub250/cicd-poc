import os
import requests
from flask import Flask, request, jsonify
import psycopg2

app = Flask(__name__)

FOUNDRY_ENDPOINT = os.environ["FOUNDRY_ENDPOINT"].rstrip("/")
FOUNDRY_API_KEY = os.environ["FOUNDRY_API_KEY"]
FOUNDRY_DEPLOYMENT = os.environ["FOUNDRY_DEPLOYMENT"]
FOUNDRY_API_VERSION = "2024-10-21"

# CI가 빌드할 때 --build-arg/ENV로 넣어주는 값. 화면 하단에 표시해서
# "소스 변경 -> 빌드 -> 배포"가 실제로 반영됐는지 눈으로 확인하는 용도.
APP_VERSION = os.environ.get("APP_VERSION", "dev")


def get_employees():
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        sslmode="require",
    )
    cur = conn.cursor()
    cur.execute('SELECT "LastName", "FirstName", "Title" FROM "Employee" ORDER BY "LastName"')
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows


@app.route("/healthz")
def healthz():
    # DB/Foundry 의존성 없이 프로세스 자체의 liveness/readiness만 확인
    return jsonify({"status": "ok", "version": APP_VERSION})


@app.route("/")
def index():
    rows = get_employees()
    html = ["<html><head><meta charset='UTF-8'><title>Employee List</title></head><body style='font-family:sans-serif; max-width:700px; margin:40px auto;'>"]
    # html.append("<h1>Employee List</h1>")
    html.append("<h1 style='color:#2563eb;'>🚀 Employee List 🚀🚀(v2)</h1>")

    html.append("<table border='1' cellpadding='6' cellspacing='0'>")
    html.append("<tr><th>Last Name</th><th>First Name</th><th>Title</th></tr>")
    for lastname, firstname, title in rows:
        html.append(f"<tr><td>{lastname}</td><td>{firstname}</td><td>{title}</td></tr>")
    html.append("</table>")

    html.append("""
    <h1>Chat</h1>
    <div id="chat-log" style="border:1px solid #ccc; padding:10px; height:300px; overflow-y:auto; margin-bottom:10px;"></div>
    <input id="chat-input" type="text" style="width:80%;" placeholder="메시지를 입력하세요">
    <button onclick="sendChat()">전송</button>
    <script>
    async function sendChat() {
      const input = document.getElementById("chat-input");
      const log = document.getElementById("chat-log");
      const message = input.value;
      if (!message) return;
      log.innerHTML += "<p><b>Me:</b> " + message + "</p>";
      input.value = "";
      log.innerHTML += "<p id='pending'><b>AI:</b> ...</p>";
      log.scrollTop = log.scrollHeight;
      try {
        const res = await fetch("/chat", {
          method: "POST",
          headers: {"Content-Type": "application/json"},
          body: JSON.stringify({message: message})
        });
        const data = await res.json();
        document.getElementById("pending").remove();
        log.innerHTML += "<p><b>AI:</b> " + (data.reply || data.error) + "</p>";
      } catch (e) {
        document.getElementById("pending").remove();
        log.innerHTML += "<p><b>AI:</b> 오류가 발생했습니다.</p>";
      }
      log.scrollTop = log.scrollHeight;
    }
    document.addEventListener("DOMContentLoaded", function() {
      document.getElementById("chat-input").addEventListener("keypress", function(e) {
        if (e.key === "Enter") sendChat();
      });
    });
    </script>
    """)

    html.append(f"<hr><p style='color:#999; font-size:12px;'>build: {APP_VERSION}</p>")
    html.append("</body></html>")
    return "".join(html)


@app.route("/chat", methods=["POST"])
def chat():
    user_message = request.get_json(silent=True) or {}
    message = user_message.get("message", "")
    if not message:
        return jsonify({"error": "message is required"}), 400

    url = f"{FOUNDRY_ENDPOINT}/openai/deployments/{FOUNDRY_DEPLOYMENT}/chat/completions?api-version={FOUNDRY_API_VERSION}"
    headers = {"Content-Type": "application/json", "api-key": FOUNDRY_API_KEY}
    payload = {"messages": [{"role": "user", "content": message}]}

    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        reply = data["choices"][0]["message"]["content"]
        return jsonify({"reply": reply})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
