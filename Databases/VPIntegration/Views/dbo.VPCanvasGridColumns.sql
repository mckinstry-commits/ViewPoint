SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE TABLE vVPCanvasGridSettings
--(
--	KeyID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
--	VPUserName VARCHAR(128) NOT NULL,
--	TabNumber INT NOT NULL,
--	Row INT NOT NULL,
--	Col INT NOT NULL,
--	QueryName VARCHAR(128) NOT NULL,
--	GridLayout VARCHAR(MAX) NULL,
--	Sort VARCHAR(128) NULL,
--	MaximumNumberOfRows INT NULL,
--	GridType INT NOT NULL,
--	ShowFilterBar bYN NOT NULL	
--);

--GO

--CREATE TABLE vVPCanvasGridColumns
--(
--	ColumnId INT IDENTITY(1,1) NOT NULL,
--	GridConfigurationId INT FOREIGN KEY REFERENCES vVPCanvasGridSettings(KeyID),
--	Name VARCHAR(128) NOT NULL,
--	IsVisible bYN NOT NULL,
--	Postion INT NOT NULL
--);
--GO

--CREATE TABLE vVPCanvasGridGroupedColumns
--(
--	ColumnId INT IDENTITY(1,1) NOT NULL,
--	GridConfigurationId INT FOREIGN KEY REFERENCES vVPCanvasGridSettings(KeyID),
--	Name VARCHAR(128) NOT NULL
--)
--GO

--CREATE TABLE vVPCanvasGridParameters
--(
--	ParamterId INT IDENTITY(1,1) NOT NULL,
--	GridConfigurationId INT FOREIGN KEY REFERENCES vVPCanvasGridSettings(KeyID),
--	Name VARCHAR(128) NOT NULL,
--	SqlType INT NOT NULL,
--	ParameterValue VARCHAR(256)
--)
--GO

--CREATE VIEW VPCanvasGridSettings
--AS
--SELECT * FROM vVPCanvasGridSettings;

CREATE VIEW [dbo].[VPCanvasGridColumns]
AS
SELECT * FROM vVPCanvasGridColumns;

GO
GRANT SELECT ON  [dbo].[VPCanvasGridColumns] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridColumns] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridColumns] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridColumns] TO [public]
GO
