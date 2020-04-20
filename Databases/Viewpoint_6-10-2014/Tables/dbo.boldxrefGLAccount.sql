CREATE TABLE [dbo].[boldxrefGLAccount]
(
[COMPANYNUMBER] [decimal] (28, 0) NULL,
[GLACCTSEG1] [decimal] (28, 0) NULL,
[GLACCTSEG2] [decimal] (28, 0) NULL,
[CGCAcct] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CGCDept] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[VPAcct] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[VPDept] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[GENLEDGERACCT] [decimal] (28, 0) NULL,
[NewVPAcct] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Code] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RecordID] [int] NOT NULL IDENTITY(1, 1),
[RecordSeq] [int] NULL
) ON [PRIMARY]
GO
