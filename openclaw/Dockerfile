FROM python:3.10-slim

WORKDIR /openclaw/configuration/

# Copy requirements file first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Expose port for Flask
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
