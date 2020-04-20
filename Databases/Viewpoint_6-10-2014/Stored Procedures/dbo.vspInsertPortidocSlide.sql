SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspInsertPortidocSlide]
@DocumentId uniqueidentifier,
@Ordinal int,
@SlideShowImage varbinary(max),
@Caption nvarchar(256),
@CreatedByUser nvarchar(128)
AS  
BEGIN
	SET NOCOUNT ON;	
	
INSERT INTO Document.DocumentSlideShow
	(	DocumentId, 
		Ordinal, 
		SlideShowImage, 
		Caption, 
		CreatedByUser, 
		DBCreatedDate, 
		Version )
	VALUES (@DocumentId, @Ordinal, @SlideShowImage, @Caption, @CreatedByUser, GETUTCDATE(), 1);

END
GO
GRANT EXECUTE ON  [dbo].[vspInsertPortidocSlide] TO [public]
GO
