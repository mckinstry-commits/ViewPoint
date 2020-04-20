using System;
using System.Collections.Generic;
using System.Linq;

namespace McKinstry.Viewpoint.ARImport
{
    /// <summary>
    /// Command invoker
    /// </summary>
    internal class CommandInvoker
    {
        private List<ICommand> commands = new List<ICommand>();

        public CommandInvoker()
        {
            LoadCommands();
        }

        /// <summary>
        /// Loads optional commands for Client
        /// </summary>
        private void LoadCommands()
        {
            commands.Add(new CheckImportFileCommand());
            commands.Add(new CheckBatchExistsCommand());
            commands.Add(new LogBatchCommand());
            commands.Add(new ExtractFilesCommand());
            commands.Add(new CheckImagesFolderCommand());
            commands.Add(new ArchiveFilesCommand());
            commands.Add(new AddDetailRecordsCommand());
            commands.Add(new ProcessDetailRecordsCommand());
            commands.Add(new AddRecordsCommand());
            commands.Add(new UpdateBatchCommand());
            commands.Add(new DeleteImportFileCommand());
            commands.Add(new EmailCommand());
        }

        /// <summary>
        /// Returns requested command
        /// </summary>
        public ICommand GetCommand(Type type)
        {
            ICommand command = null;
            command = commands.
                Where(c => c.GetType() == type)
                .FirstOrDefault<ICommand>();
            if (command == default(ICommand))
            {
                throw new ApplicationException(string.Format("Command invoker exception. Unable to find loaded command of type '{0}'.", type.Name));
            }
            return command;
        }
    }
}
