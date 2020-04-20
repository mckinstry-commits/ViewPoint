CREATE TABLE [dbo].[budxrefPRDept_McK_20140130]
(
[CGCCompany] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CGCGLDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CGCGLDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CGCPRDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CGCPRDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[VPGLDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[VPGLDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VPPRDeptDesc] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[VPPRDeptNumber] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[VPProductionCompany] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[VPTestCompany] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
