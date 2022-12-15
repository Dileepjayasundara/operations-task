[
    {
      "name": "${name}",
      "image": "${image}",
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp",
          "hostPort": 3000
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": { 
          "awslogs-group" : "${awslogs-group}",
          "awslogs-region": "${region}",
          "awslogs-stream-prefix": "awslogs-example"
        }
      }
    }
]