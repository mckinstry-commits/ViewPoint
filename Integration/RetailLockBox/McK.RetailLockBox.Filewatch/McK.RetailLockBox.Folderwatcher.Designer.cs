namespace McK.RetailLockBox.Folderwatch
{
    partial class RLB_DownloadFolderwatcher
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.APFolderWatcher = new System.IO.FileSystemWatcher();
            this.eventLog1 = new System.Diagnostics.EventLog();
            this.ARFolderWatcher = new System.IO.FileSystemWatcher();
            ((System.ComponentModel.ISupportInitialize)(this.APFolderWatcher)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.eventLog1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.ARFolderWatcher)).BeginInit();
            // 
            // APFolderWatcher
            // 
            this.APFolderWatcher.EnableRaisingEvents = true;
            this.APFolderWatcher.Filter = "*.zip";
            // 
            // ARFolderWatcher
            // 
            this.ARFolderWatcher.EnableRaisingEvents = true;
            this.ARFolderWatcher.Filter = "*.zip";
            // 
            // RLB_DownloadFolderwatcher
            // 
            this.AutoLog = false;
            this.CanPauseAndContinue = true;
            this.ServiceName = "McK RLB Download To Drop Folder Watcher";
            ((System.ComponentModel.ISupportInitialize)(this.APFolderWatcher)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.eventLog1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.ARFolderWatcher)).EndInit();

        }

        #endregion

        private System.IO.FileSystemWatcher APFolderWatcher;
        private System.Diagnostics.EventLog eventLog1;
        private System.IO.FileSystemWatcher ARFolderWatcher;
    }
}
