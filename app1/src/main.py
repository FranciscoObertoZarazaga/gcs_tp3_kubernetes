from fastapi import FastAPI

app = FastAPI()

@app.get("/app1/ping/")
def ping():
    return {"status": True, "message": "Pong!", "version": "2.0"}
