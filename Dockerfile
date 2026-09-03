# Use official Python slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Create a non-root user for security
RUN adduser --disabled-password --gecos '' appuser
EXPOSE 8000

# Copy project files needed for installation
COPY pyproject.toml requirements.txt README.md LICENSE ./
COPY src/ ./src/

# Install dependencies
RUN pip install --no-cache-dir -e .

# Change to non-root user
USER appuser

# The edupage-mcp-full console script is installed by the editable install above
# Alternatively, we can use: python -m edupage_mcp
ENTRYPOINT ["python", "-m", "edupage_mcp"]