from typing import List, Optional
from flask import Flask, make_response, request, render_template
from terraria import Terraria
from pathlib import Path
from threading import RLock

app = Flask(__name__)
if __name__ == "__main__":
    app.run()

class TerrariaSingleton:
    terraria: Optional[Terraria] = None
    lock = RLock()

    @classmethod
    def get(cls) -> Optional[Terraria]:
        with cls.lock:
            if cls.terraria != None and not cls.terraria.running():
                cls.terraria = None
            return cls.terraria

    @classmethod
    def new(cls):
        base_path = Path(__file__).parent.parent
        launch_path = base_path.joinpath("server/launch.txt")
        if not launch_path.exists():
            raise FileExistsError("launch.txt not found")
        
        with launch_path.open("r") as f:
            exe_path = Path(f.readline().strip())

        with cls.lock:
            cls.terraria = Terraria(
                exe_path,
                data_path=base_path.joinpath("data").resolve(),
                world_name="TestWorld",
                password="barbaz",
                motd="yooo whatsuppp!!!"
            )

def get_logs(terraria: Optional[Terraria]) -> List[str]:
    if terraria:
        return terraria.output(200)
    else:
        return []

@app.route("/term")
def get_term():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("term.html", running=terraria != None, logs=get_logs(terraria))

@app.route("/output")
def get_output():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("server_output.html", logs=get_logs(terraria))

@app.route("/status")
def get_status():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("status.html", running=terraria != None)

@app.route("/")
def get_main():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("main.html", running=terraria != None, logs=get_logs(terraria))

@app.route("/cmds/start", methods=["POST"])
def start_server():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            TerrariaSingleton.new()

    resp = make_response("Starting server...")
    resp.headers.set("HX-Trigger", "terraria:statusChange")
    return resp

@app.route("/cmds/stop", methods=["POST"])
def stop_server():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            return "Terraria server has not been started."
        terraria.exit()

    resp = make_response("Stopping server...")
    resp.headers.set("HX-Trigger", "terraria:statusChange")
    return resp


@app.route("/cmds/custom", methods=["POST"])
def send_cmd():
    cmd = request.form.get("cmd", "").strip()
    events = ["terraria:outputChange"]

    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if terraria:
            terraria.send(cmd)

            if cmd in ["exit", "exit-nosave"]:
                events.append("terraria:statusChange")
                terraria.wait()
    
    resp = make_response("Sending command...")
    resp.headers.set("HX-Trigger", ", ".join(events))
    return resp