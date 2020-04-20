namespace McKinstry.Viewpoint.DropFolderWatcher
{
    partial class ProjectInstaller
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
            this.DropFolderServiceProcessInstaller = new System.ServiceProcess.ServiceProcessInstaller();
            this.DropFolderWatcerServiceInstaller = new System.ServiceProcess.ServiceInstaller();
            // 
            // DropFolderServiceProcessInstaller
            // 
            this.DropFolderServiceProcessInstaller.Password = null;
            this.DropFolderServiceProcessInstaller.Username = null;
            // 
            // DropFolderWatcerServiceInstaller
            // 
            this.DropFolderWatcerServiceInstaller.Description = "Watches RLB drop folder for new files.  Starts AP/AR processes based on dropped f" +
    "ile.";
            this.DropFolderWatcerServiceInstaller.DisplayName = "McKinstry RLB Drop Folder File Watcher";
            this.DropFolderWatcerServiceInstaller.ServiceName = "DropFolderWatcherService";
            this.DropFolderWatcerServiceInstaller.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            // 
            // ProjectInstaller
            // 
            this.Installers.AddRange(new System.Configuration.Install.Installer[] {
            this.DropFolderServiceProcessInstaller,
            this.DropFolderWatcerServiceInstaller});

        }

        #endregion

        private System.ServiceProcess.ServiceInstaller DropFolderWatcerServiceInstaller;
        private System.ServiceProcess.ServiceProcessInstaller DropFolderServiceProcessInstaller;
    }
}