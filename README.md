# Plugin: Fixtures

## Purpose

The cfwheels fixtures provides utilities to dump database tables into json fixtures or load json fixtures and create/populate database tables.

## Configuration

Configuration Instructions

## Usage

Usage Instructions

create a fixtures folder in your cfwheels tests folder. 
    cfwheelsroot/tests/fixtures


```java
dumpData(
    ["usertiers","elanusers","brochures"],
    "tests/fixtures/usertiers.json",
    true,
    50
);
```


from a test for example

```java
loadData(fixtures = ["usertiers.json"]);
```
