SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[mfnEnumerateJobs]
(
     @ConJobValue varchar(4000)
    ,@Delimiter char(1)
    ,@ConJobFlag char(1)
)
RETURNS TABLE 
AS
/****************************************************************************************************
* mfnEnumerateJobs                                                                                  *
*    This function enumerates and returns jobs in a table from input Contracts and Jobs             *
*    It can handle multiple values separated by a delimiter, e.g. '1233-,4388-'                     *
*                                                                                                   *
*    @ConJobValue is contract values or job values                                                  *
*    @Delimiter is delimiter used in separating multiple values e.g. '1233-,4388-'                  *
*    @ConJobFlag is 'C' when input is contract and 'J' when input is jop                            *
*                                                                                                   *
* Date         By             Comment                                                               *
* ==========   ===========    =========================================================             *
* 04/24/2014   Zachf          Created                                                               *
* 06/05/2014   Zachf          Added RTRIM before LTRIM(jcjm.Contract)                               *
*                                                                                                   *
*                                                                                                   *
****************************************************************************************************/
RETURN 
(
   SELECT
      jcjm.Job
   FROM
      JCJM jcjm
      CROSS APPLY dbo.mfnSplitString(@ConJobValue,@Delimiter) items
   WHERE
      RTRIM(LTRIM(jcjm.Contract)) LIKE RTRIM(LTRIM(items.Item)) + '%'
      AND @ConJobFlag = 'C'

   UNION 

   SELECT
      jcjm.Job
   FROM
      JCJM jcjm
   CROSS APPLY dbo.mfnSplitString(@ConJobValue,@Delimiter) items
   WHERE
      RTRIM(LTRIM(jcjm.Job)) LIKE RTRIM(LTRIM(items.Item)) + '%'
      AND @ConJobFlag = 'J'

)
GO
