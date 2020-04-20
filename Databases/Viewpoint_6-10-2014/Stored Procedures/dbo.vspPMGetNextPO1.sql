SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPMGetNextPO  ******/
CREATE proc [dbo].[vspPMGetNextPO1]
/**************************************************************************
      Created By:       VCS Tech Services - Jake Fisher
      Modified By:            
      Usage:            Used to get the next purchase order number formatted to
						today's Julian Date + Sequence Number.
            Pass:
                  Project           PM Project
                  

                  Success returns:
                        0 - Success
                        1 - ERROR
                  
                  Output:
                        @PO - Next purchase order

                  Error:
                        1 and error message
**************************************************************************/
	(
		@PMCo		VARCHAR(30)	= NULL,
		@Project	VARCHAR(30)	= NULL, 
		@POCo		VARCHAR(30)	= NULL,
		@PO			VARCHAR(30)	= NULL OUTPUT
		)

AS
SET NOCOUNT ON
 
declare @rcode int, @retcode int, @pono varchar(1), @posigpartjob bYN, @validpartjob varchar(30),
		@pocharsproject tinyint, @pocharsvendor tinyint, @projectpart bProject,
		@formattedpo varchar(30), @tmppo varchar(30), @poseqlen int, @mseq int,
		@paddedstring varchar(60), @tmpseq varchar(30), @sigcharspo smallint,
		@tmpproject varchar(30), @actchars smallint, @polength varchar(10), @pomask varchar(30),
		@dummy_po varchar(30), @tmppo1 varchar(30), @i int, @value varchar(1), @tmpseq1 varchar(10),
		@postartseq smallint, @counter int

select @rcode = 0, @PO = '', @counter = 0

if @PMCo is null or @Project is null or @POCo is null
begin
	select @rcode = 1
	goto bspexit
end

/**Get input mask for bPO**/
      SELECT 
            @pomask           = InputMask, 
            @polength   = CONVERT(VARCHAR(10), InputLength)
      FROM DDDTShared WITH (NOLOCK)
      WHERE Datatype = 'bPO'
      
            IF ISNULL(@pomask,'') = '' 
                  SELECT @pomask = 'L'
            
            IF ISNULL(@polength,'') = '' 
                  SELECT @polength = '10'
                  
            IF @pomask in ('R','L')
                  BEGIN
                        SELECT @pomask = @polength + @pomask + 'N'
                  END


      SELECT 
            @tmppo      = NULL, 
            @tmppo1     = NULL, 
            @mseq = 1
            
/**Max from PMMF**/
      SELECT @tmppo = LTRIM(RTRIM(MAX(PO))) 
      FROM bPMMF 
      WHERE SUBSTRING(PO,1,5) = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))

/**Max from POHD, POHB, POPendingPurchaseOrder**/
      SELECT @tmppo1 = LTRIM(RTRIM(MAX(PO))) 
      FROM dbo.POUnique 
      WHERE SUBSTRING(PO,1,5) = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
      

/**Use highest to get next sequence**/
      IF ISNULL(@tmppo,'') <> '' AND ISNULL(@tmppo1,'') = ''
            SELECT @tmppo1 = @tmppo
      
      IF ISNULL(@tmppo1,'') <> '' AND ISNULL(@tmppo,'') = ''
            SELECT @tmppo = @tmppo1

      IF @tmppo1 > @tmppo 
            SELECT @tmppo = @tmppo1

/**Build PO**/
      build_po:

      /**format po using appropiate value**/
      SELECT 
            @dummy_po         = NULL, 
            @formattedpo      = NULL
            
      SET @dummy_po = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
                              + RIGHT('000'+ CONVERT(VARCHAR,(ROW_NUMBER() OVER (PARTITION BY @PO ORDER BY @PO))),3)
      
      EXEC @retcode = dbo.bspHQFormatMultiPart @dummy_po, @pomask, @formattedpo output

/**Check if purchase order already exists**/

      IF EXISTS
            (SELECT * FROM POHD WITH (NOLOCK) WHERE PO=@formattedpo)
      OR EXISTS
            (SELECT * FROM dbo.POUnique WHERE PO=@formattedpo)
      
            BEGIN 
                  SELECT @formattedpo = LTRIM(RTRIM(MAX(PO)+1)) from bPOHD where SUBSTRING(PO,1,5) = CONVERT(VARCHAR(30),dbo.JulianDate(GETDATE()))
            end
            
      ELSE
            SELECT @formattedpo = LTRIM(RTRIM(@formattedpo))

      SELECT @PO = @formattedpo

select @PO = '123456789'


bspexit:
      return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextPO1] TO [public]
GO
