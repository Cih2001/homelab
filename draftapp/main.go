package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	// Database connection details
	host := "postgres" // This is the service name defined in the Kubernetes YAML
	port := 5432
	user := "myuser"
	password := "mypassword"
	dbname := "mydatabase"

	// Construct the connection string
	dsn := fmt.Sprintf("postgres://%s:%s@%s:%d/%s", user, password, host, port, dbname)

	// Create a connection pool
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		log.Fatalf("Unable to parse database URL: %v", err)
	}

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		log.Fatalf("Unable to create connection pool: %v", err)
	}
	defer pool.Close()

	// Ping the database to verify connection
	err = pool.Ping(context.Background())
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}

	fmt.Println("Successfully connected to the database!")

	// Execute a simple query
	var currentTime string
	err = pool.QueryRow(context.Background(), "SELECT NOW()").Scan(&currentTime)
	if err != nil {
		log.Fatalf("Error executing query: %v", err)
	}

	fmt.Printf("Current time from the database: %s\n", currentTime)
}
