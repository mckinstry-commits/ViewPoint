CREATE TABLE [dbo].[vDDAssemblyDependency]
(
[Assembly] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[DependentAssembly] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDAssemblyDependency] ADD CONSTRAINT [PK_vDDAssemblyDependency] PRIMARY KEY CLUSTERED  ([Assembly], [DependentAssembly]) ON [PRIMARY]
GO
