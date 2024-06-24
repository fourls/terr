from typing import Optional
from flask import Flask, render_template
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

@app.route("/logs")
def get_logs():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            return "Terraria server has not been started."
        output = terraria.output()[-200:]
        print(output)
        
        return render_template("logs.html", logs=output)

@app.route("/")
def get_index():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            return render_template("main.html", server_started=False)
        output = terraria.output()[-200:]

    return render_template("main.html", logs=output, server_started=True)

@app.route("/cmds/help", methods=["POST"])
def send_help():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            return "Terraria server has not been started."
        terraria.send("help")
    
    return "Help requested"

@app.route("/cmds/start", methods=["POST"])
def send_start():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if terraria:
            return "Terraria server is already started."
        TerrariaSingleton.new()

    return render_template("main.html", server_started=True)

@app.route("/cmds/stop", methods=["POST"])
def send_stop():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            return "Terraria server has not been started."
        terraria.exit()
    
    return render_template("main.html", server_started=False)