---
skip: {{ has_backend == false }}
---

DROP DATABASE IF EXISTS `{{ project_name | snake_case }}`;
CREATE DATABASE `{{ project_name | snake_case }}`;
