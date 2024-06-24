from typing import List, Optional
from flask import Flask, make_response, redirect, request, render_template
from terraria import Terraria
from pathlib import Path
from threading import RLock
from flask_login import LoginManager, login_user, logout_user, login_required, current_user

app = Flask(__name__)
app.secret_key = "so secret!!"
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "index" # type: ignore

class User:
    def __init__(self, id: str, name: str, password: str):
        self.id = id
        self.name = name
        self.password = password

    def get_id(self) -> str:
        return self.id
    
    @property
    def is_authenticated(self) -> bool:
        return True
    
    @property
    def is_active(self) -> bool:
        return True
    
    @property
    def is_anonymous(self) -> bool:
        return False

ADMIN_USER = User("admin", "HE9164", "gold36")

@login_manager.user_loader
def load_user(id: str):
    if id == ADMIN_USER.get_id():
        return ADMIN_USER
    else:
        return None

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

@app.route("/")
def index():
    if current_user.is_authenticated:
        return redirect("/dashboard")
    
    return render_template("login.html")

@app.route("/login", methods=["POST"])
def login():
    user = request.form.get("user", None)
    password = request.form.get("password", None)

    if user == ADMIN_USER.name and password == ADMIN_USER.password:
        assert(login_user(ADMIN_USER))

    return redirect("/dashboard")

@app.route("/logout", methods=["POST"])
@login_required
def logout():
    logout_user()

    resp = make_response("Logged out")
    resp.headers.set("HX-Redirect", "/")
    return resp

@app.route("/style")
@login_required
def get_css():
    resp = make_response(render_template("style.css"))
    resp.content_type = "text/css"
    return resp

@app.route("/term")
@login_required
def get_term():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("term.html", running=terraria != None, logs=get_logs(terraria))

@app.route("/output")
@login_required
def get_output():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("server_output.html", logs=get_logs(terraria))

@app.route("/status")
@login_required
def get_status():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("status.html", running=terraria != None)

@app.route("/dashboard")
@login_required
def get_dashboard():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        return render_template("main.html", running=terraria != None, logs=get_logs(terraria))

@app.route("/cmds/start", methods=["POST"])
@login_required
def start_server():
    with TerrariaSingleton.lock:
        terraria = TerrariaSingleton.get()
        if not terraria:
            TerrariaSingleton.new()

    resp = make_response("Starting server...")
    resp.headers.set("HX-Trigger", "terraria:statusChange")
    return resp

@app.route("/cmds/stop", methods=["POST"])
@login_required
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
@login_required
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