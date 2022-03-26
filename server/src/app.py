import os
from functools import wraps
from pathlib import Path

from flask import (
    Flask,
    render_template,
    request,
    session,
    flash,
    redirect,
    url_for,
    jsonify,
    abort,
)
from flask_sqlalchemy import SQLAlchemy

basedir = Path(__file__).resolve().parent

# create and initialize a new Flask app
app = Flask(__name__)
SECRET_KEY = "change_me"
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///monitoring.sqlite3'
# init sqlalchemy
db = SQLAlchemy(app)

class logins(db.Model):
   hostname = db.Column(db.String(100), primary_key = True)
   count = db.Column(db.Integer)

   def __init__(self, hostname, count):
       self.hostname = hostname
       self.count = count

@app.route("/")
def index():
    data = db.session.query(logins).all()
    print(data)
    return "GOOD"


@app.route("/add", methods=["POST"])
def add_entry():
    """Adds new post to the database."""
    print("REQUEST JSON = ",request.json)
    data=request.json
    exists = db.session.query(logins).get(data["hostname"])
    print(exists)
    if not exists==None:
        exists.count = data["count"]
        db.session.commit()
        return "Bahut Ache"
    else:
        new_entry = logins(data["hostname"], data["count"])
        db.session.add(new_entry)
        db.session.commit()
    return "GOOD" #redirect(url_for("index"))

@app.before_first_request
def create_tables():
    print("Creating Databases")
    res = db.create_all()
    print("RESULT = ", res)

if __name__ == "__main__":
    app.run()
