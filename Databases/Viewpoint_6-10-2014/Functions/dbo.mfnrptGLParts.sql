SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnrptGLParts]
(
	@GLCo bCompany
)
RETURNS @GLParts TABLE
(
GLCo tinyint null,
P1Desc varchar(30) null,
P2Desc varchar(30) null,
P3Desc varchar(30) null,
P4Desc varchar(30) null,
P5Desc varchar(30) null,
P6Desc varchar(30) NULL
)
AS
BEGIN
 
	/* fill GL Parts */
	insert into @GLParts
	select GLCO.GLCo, GLPD1.Description, GLPD2.Description,GLPD3.Description,
	GLPD4.Description, GLPD5.Description,GLPD6.Description
	from GLCO
	Left Join GLPD as GLPD1 on GLPD1.GLCo=GLCO.GLCo and GLPD1.PartNo=1
	Left Join GLPD as GLPD2 on GLPD2.GLCo=GLCO.GLCo and GLPD2.PartNo=2
	Left Join GLPD as GLPD3 on GLPD3.GLCo=GLCO.GLCo and GLPD3.PartNo=3
	Left Join GLPD as GLPD4 on GLPD4.GLCo=GLCO.GLCo and GLPD4.PartNo=4
	Left Join GLPD as GLPD5 on GLPD5.GLCo=GLCO.GLCo and GLPD5.PartNo=5
	Left Join GLPD as GLPD6 on GLPD6.GLCo=GLCO.GLCo and GLPD6.PartNo=6
	where GLCO.GLCo=@GLCo

	RETURN
END
GO
