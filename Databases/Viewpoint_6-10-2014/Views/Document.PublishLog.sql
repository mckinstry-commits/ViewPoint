SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[PublishLog]
	AS SELECT * FROM [Document].[vPublishLog]
GO
GRANT SELECT ON  [Document].[PublishLog] TO [public]
GRANT INSERT ON  [Document].[PublishLog] TO [public]
GRANT DELETE ON  [Document].[PublishLog] TO [public]
GRANT UPDATE ON  [Document].[PublishLog] TO [public]
GO
