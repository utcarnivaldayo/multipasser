---
skip: {{ has_backend == false }}
---

DROP USER IF EXISTS 'api'@'%';
CREATE USER 'api'@'%' IDENTIFIED BY 'api';
GRANT ALL ON `{{ project_name | snake_case }}`.* TO 'api'@'%';

DROP USER IF EXISTS 'batch'@'%';
CREATE USER 'batch'@'%' IDENTIFIED BY 'batch';
GRANT ALL ON `{{ project_name | snake_case }}`.* TO 'batch'@'%';

FLUSH PRIVILEGES;
