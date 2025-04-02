from fastapi import FastAPI, Response
import os
import json
import requests
from typing import Dict
import psycopg2

app = FastAPI()

@app.get("/health/liveliness")
async def liveliness() -> Dict:
    """Basic health check to verify the service is running"""
    return {"status": "healthy"}

@app.get("/health/readiness")
async def readiness() -> Response:
    """Deeper health check that verifies connectivity to dependencies"""
    health_status = {"status": "healthy", "checks": {}}
    http_status = 200
    
    # Check database connectivity
    try:
        conn = psycopg2.connect(
            host=os.environ.get("DB_HOST"),
            port=os.environ.get("DB_PORT"),
            dbname=os.environ.get("DB_NAME"),
            user=os.environ.get("DB_USER"),
            password=os.environ.get("DB_PASSWORD"),
            connect_timeout=5
        )
        conn.close()
        health_status["checks"]["database"] = "connected"
    except Exception as e:
        health_status["checks"]["database"] = f"error: {str(e)}"
        health_status["status"] = "unhealthy"
        http_status = 503
    
    # Check LiteLLM service
    try:
        litellm_port = os.environ.get("PORT", "4000")
        response = requests.get(f"http://localhost:{litellm_port}/v1/models", timeout=2)
        if response.status_code == 200:
            health_status["checks"]["litellm"] = "connected"
        else:
            health_status["checks"]["litellm"] = f"error: status code {response.status_code}"
            health_status["status"] = "unhealthy"
            http_status = 503
    except Exception as e:
        health_status["checks"]["litellm"] = f"error: {str(e)}"
        health_status["status"] = "unhealthy"
        http_status = 503
    
    return Response(
        content=json.dumps(health_status),
        media_type="application/json",
        status_code=http_status
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
