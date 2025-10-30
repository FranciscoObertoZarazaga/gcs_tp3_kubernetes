from fastapi import FastAPI

app = FastAPI()

@app.get("/ping/")
def ping():
    return {"status": True, "message": "Pong!", "version": "1.0"}
