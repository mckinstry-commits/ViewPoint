SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Create Date:	06/11/2010
* Created By:	Jonathan Paullin
* Modified By:	AMR - 6/27/11 - TK-06411, Fixing performance issue by using an inline table function.	
*		     
* Description: Gets formatting information on a DDFI entry.
*
* Inputs: 
*
* Outputs:
*
*************************************************/
CREATE PROCEDURE [dbo].[vspDDFIGetFormatInfo]
    @Form VARCHAR(30),
    @Seq SMALLINT,
    @ErrorMessage VARCHAR(512) OUTPUT
AS 
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON ;

        BEGIN TRY
	
            IF @Form = '' 
                BEGIN
                    SET @ErrorMessage = 'Form not specificed.'
                    RAISERROR (50000, 15, 1)
                END				
	
            SELECT  COALESCE(DDDT.InputType, DDFI.InputType, 0) AS InputType,
                    COALESCE(DDDT.InputMask, DDFI.InputMask, '') AS InputMask,
                    COALESCE(DDDT.InputLength, DDFI.InputLength, 0) AS InputLength,
                    COALESCE(DDDT.Prec, DDFI.Prec, 0) AS PRECISION
                    -- use inline table function for perf
            FROM    dbo.vfDDFIShared(@Form) DDFI
                    LEFT JOIN DDDTShared DDDT ON DDFI.Datatype = DDDT.Datatype
            WHERE   DDFI.Seq = @Seq
	
        END TRY
        BEGIN CATCH
            IF ERROR_NUMBER() = 50000 
                BEGIN
                    RETURN -1
                END	
        END CATCH	

        RETURN 0
    END

GO
GRANT EXECUTE ON  [dbo].[vspDDFIGetFormatInfo] TO [public]
GO
