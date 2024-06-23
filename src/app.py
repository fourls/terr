from flask import Flask, render_template
from terraria import Terraria
from pathlib import Path

app = Flask(__name__)
if __name__ == "__main__":
    app.run()

base_path = Path(__file__).parent.parent.resolve()
terraria = Terraria(
    base_path.joinpath("server/launch.sh"),
    data_path=base_path.joinpath("data"),
    world_name="TestWorld",
    password="barbaz",
    motd="yooo whatsuppp!!!"
)

@app.route("/logs")
def get_logs():
    return render_template("logs.html", logs=terraria.output())

@app.route("/")
def get_index():
    return render_template("main.html", logs=terraria.output())