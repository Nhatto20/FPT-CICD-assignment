# Port Mapping Requirements

The application runs on port `8000` internally within the container (exposed via the `EXPOSE 8000` directive in the Dockerfile).

For local development and access from the host machine, the port is mapped as follows:

- **Host Port**: `8000`
- **Container Port**: `8000`

### Mapping Syntax
In `docker-compose.yml`:
```yaml
ports:
  - "8000:8000"
```

In the `docker run` command:
```bash
docker run -p 8000:8000 myapp:prod
```

### Important Notes
- Ensure port `8000` on the host machine is not being used by another application.
- If port `8000` is occupied by another service on your machine, you can change the host port mapping (e.g., `"8080:8000"`). This will allow you to access the app at `http://localhost:8080` while it continues to run on port `8000` inside the container.
