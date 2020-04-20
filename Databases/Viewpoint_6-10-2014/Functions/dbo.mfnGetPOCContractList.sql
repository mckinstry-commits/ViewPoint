SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnGetPOCContractList] (
   @POC int
)
RETURNS varchar(255)
AS
/****************************************************************************************************
* mfnGetPOCContractList                                                                             *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 03/25/2014   ZachF          Return all contracts for a given POC in a string                      *
*                                                                                                   *
*                                                                                                   *
****************************************************************************************************/
BEGIN

DECLARE @ContractList varchar(255);

IF (SELECT COUNT(Contract) FROM JCCM WITH (READUNCOMMITTED) WHERE udPOC = @POC) > 0
BEGIN
   WITH ContractList(RowNum, Contracts) AS
   (
      SELECT
         1, CAST('' AS varchar(255))
      UNION ALL
         SELECT
             cl.RowNum + 1
            ,CAST(cl.Contracts + jccm.Contract + ',' AS varchar(255))
         FROM
            (
               SELECT
                   RowNum = ROW_NUMBER() OVER (ORDER BY Contract)
                  ,Contract
               FROM
                  JCCM WITH (READUNCOMMITTED)
               WHERE
                  udPOC = @POC
            ) jccm
         JOIN
            ContractList cl
               ON jccm.RowNum = cl.RowNum
   )
   SELECT TOP 1 @ContractList = SUBSTRING(Contracts,1,LEN(Contracts)-1) FROM ContractList ORDER BY RowNum DESC;
END
ELSE
   SET @ContractList = null;

RETURN @ContractList;

END
GO
