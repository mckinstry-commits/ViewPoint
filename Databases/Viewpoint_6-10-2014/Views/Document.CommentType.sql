SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW Document.CommentType
AS

SELECT * FROM Document.vCommentType
GO
GRANT SELECT ON  [Document].[CommentType] TO [public]
GRANT INSERT ON  [Document].[CommentType] TO [public]
GRANT DELETE ON  [Document].[CommentType] TO [public]
GRANT UPDATE ON  [Document].[CommentType] TO [public]
GO
