---
layout: post
title: MySQL Performance
date: 2018-02-13 13:56:56
description: Tips for SQL performance with MySQL
tags: "mysql", "performance", "sql"
---

- Knows the [output][explain-output] from [`explain`][explain-tutorial]
- Profile your query: [SHOW PROFILE][show-profile]
- See [how Optimizer made decision][optimizer]
- [Use index][use-index], don't abuse because index takes space
- String column could use [index prefix][mysql-create-index] to save space (pick length wisely)
- `OR` cannot leverage index ([maybe `UNION` can help][union])
- MySQL not using your index: [Index Hints][index_hints]
  - `FORCE INDEX` tell MySQL to use particular index
- The index is the cause of slow
  - `IGNORE INDEX` tell MySQL NOT to use particular index
- [Normalize or denormalize][nor-denor]
- [Do Multiple-row INSERT instead of INSERT][bulk-data-load]
- Large Data Manipulation
  - [`SELECT INTO OUTFILE`][select] + [`LOAD DATA INFILE`][load]
  - Amazon RDS, Aurora: [`SELECT INTO OUTFILE S3`][select-s3] + [`LOAD DATA FROM S3`][load-s3]
- [Optimize for InnoDB][opt-innodb]

[explain-output]: https://dev.mysql.com/doc/refman/5.7/en/explain-output.html
[explain-tutorial]: https://dev.mysql.com/doc/workbench/en/wb-tutorial-visual-explain-dbt3.html
[show-profile]: https://dev.mysql.com/doc/refman/5.7/en/show-profile.html
[optimizer]: https://dev.mysql.com/doc/internals/en/optimizer-tracing.html
[use-index]: https://use-the-index-luke.com
[mysql-create-index]: https://dev.mysql.com/doc/refman/5.7/en/create-index.html
[union]: https://stackoverflow.com/a/2829800/517868
[index_hints]: https://dev.mysql.com/doc/refman/5.7/en/index-hints.html
[nor-denor]: http://database-programmer.blogspot.jp/search/label/denormalization
[bulk-data-load]: https://dev.mysql.com/doc/refman/5.7/en/optimizing-innodb-bulk-data-loading.html
[select]: https://dev.mysql.com/doc/refman/5.7/en/select.html
[load]: https://dev.mysql.com/doc/refman/5.7/en/load-data.html
[select-s3]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraMySQL.Integrating.SaveIntoS3.html#AuroraMySQL.Integrating.SaveIntoS3.Statement
[load-s3]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AuroraMySQL.Integrating.LoadFromS3.html#AuroraMySQL.Integrating.LoadFromS3.Text
[opt-innodb]: https://dev.mysql.com/doc/refman/5.7/en/optimizing-innodb.html
