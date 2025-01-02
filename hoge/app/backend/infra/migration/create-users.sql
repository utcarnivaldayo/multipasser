DROP USER IF EXISTS 'api'@'%';
CREATE USER 'api'@'%' IDENTIFIED BY 'api';
GRANT ALL ON `hoge`.* TO 'api'@'%';

DROP USER IF EXISTS 'batch'@'%';
CREATE USER 'batch'@'%' IDENTIFIED BY 'batch';
GRANT ALL ON `hoge`.* TO 'batch'@'%';

FLUSH PRIVILEGES;