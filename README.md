# Rails API with Prometheus Integration

A simple Ruby on Rails API project with Prometheus metrics integration. This project is currently under development, with plans to add more metrics and future Grafana integration for enhanced monitoring visualization.

## Tech Stack

- Ruby 3.2.2
- Rails 7.1.5
- PostgreSQL
- Redis
- Prometheus Client

## Running with Docker

1. Build and start the containers:

```bash
docker-compose up --build
```

2. Setup the database:

```bash
docker-compose exec web rails db:create db:migrate
```

## API Endpoints

### Todos

- GET /todos - List all todos
- GET /todos/:id - Get a specific todo
- POST /todos - Create a new todo
- PUT /todos/:id - Update a todo
- DELETE /todos/:id - Delete a todo

### Example Request

Create a new todo:

```bash
curl -X POST http://localhost:3000/todos \
  -H "Content-Type: application/json" \
  -d '{
    "todo": {
      "title": "Learn Prometheus",
      "description": "Study metrics and monitoring",
      "completed": false
    }
  }'
```

## Metrics

Access Prometheus metrics at:

```bash
http://localhost:3000/metrics
```

## Future Enhancements

- Additional custom metrics
- Grafana dashboard integration
- Performance monitoring dashboards
- Extended documentation
