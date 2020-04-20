using System;
using System.Collections.Generic;
using System.Linq;

namespace McKinstry.Viewpoint.RemoteFileDownload
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
            commands.Add(new DownloadCheckCommand());
            commands.Add(new DownloadCommand());
            commands.Add(new EmailCommand());
            commands.Add(new LogCommand());
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
