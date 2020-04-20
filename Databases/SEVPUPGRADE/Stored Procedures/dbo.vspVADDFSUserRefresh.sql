SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Aaron Lang, vspVADDFSUserRefresh>
-- Create date: <6/1/07>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDFSUserRefresh]

(@NameArray VARCHAR(8000),@ModArray VARCHAR(8000), @CoArray VARCHAR(8000)) --, 

	-- Add the parameters for the stored procedure here
AS
Begin

	Declare @Name as varchar(150), @Co as SMALLINT, @Value as VARCHAR(100),@Comma AS CHAR(2), @Mod AS VARCHAR(200)





BEGIN

	SELECT h.Mod, HQCo as Co,h.Form,[VPUserName], 3 as Access, 'N' AS RecAdd,'N' AS RecUpdate,'N' as RecDelete

	from DDUP

	Cross join (Select Mod, Form from DDFH where Left(Form,2) <> 'DD' AND Mod IN (SELECT Names FROM vfTableFromArray(@ModArray))) h

	Cross join (SELECT HQCo FROM HQCO WHERE HQCo IN (SELECT Company FROM vfCoTableFromArray(@CoArray))) c

	where [VPUserName] IN (SELECT Names FROM vfTableFromArray(@NameArray))

	and Form not in(

	select Form from DDFS

	where [VPUserName] IN (SELECT Names FROM vfTableFromArray(@NameArray)) and Co =HQCo )-- and HQCo = @Co

	union 

	select Mod, [Co], f.[Form], [Access], [RecAdd], [RecUpdate], [RecDelete], f.[VPUserName]  from DDFS f JOIN DDUP h ON f.[VPUserName] = h.[VPUserName]  JOIN DDFH g ON f.[Form] = g.[Form]

	where f.[VPUserName] IN (SELECT Names FROM vfTableFromArray(@NameArray)) and Co IN (SELECT Company FROM vfCoTableFromArray(@CoArray)) AND Mod IN (SELECT Names FROM vfTableFromArray(@ModArray))

END

END 

SELECT * FROM DDUP
GO
GRANT EXECUTE ON  [dbo].[vspVADDFSUserRefresh] TO [public]
GO
