from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/api/ping")
def ping():
    return {"message": "pong"}


@app.get("/api/version")
def version():
    return {"name": "myapp", "version": "0.1.0"}
