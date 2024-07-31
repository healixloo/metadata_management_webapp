library(readr)

# Step 1: Read DataHub.txt into a data frame
#data_hub <- read.table("/home/lakatos/jlu/jlu/meta_template_spreadsheet_20240430/data_on_cloud/lab/DataHub.txt", header = TRUE)
data_hub <- read.table("/gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/data_on_cloud/lab/DataHub.txt", header = TRUE)
# to make it work in shinyapp, we should replace the link path with the absolute path, which is found by the simple shinyapp: /u2/tmp/shiny-server/jlu/test/test_system/
# Step 2: Get list of files in folderA
folder_path <- "/gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/data_on_cloud"

all_files <- list.files(folder_path, full.names = TRUE,recursive = TRUE)
file_names<-all_files[!grepl("lab", all_files)]
copypath <- paste("/gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/copy/lab/",Sys.Date(),".datahub.txt",sep="")
new_group<-"mbiome"

data_hub<-data_hub[1,]

# Step 3: Iterate over each file in folderA
for (file_name in file_names) {
  # Extract file name
  file_base_name <- basename(file_name)
  # Check if file name already exists in DataHub.txt
  if (file_base_name %in% data_hub$Identifier) {
    next  # Skip to next file if file name exists
  }
  
  # Read file into a data frame
  file_data <- read.table(file_name, header = TRUE)
  
  # Extract values from third column of file
  extractrows<-c(3,4,5,24,28,30,31,32,33,34,35,12,47,25)
  values <- file_data[extractrows,3]
  
  # Add values to new row in DataHub.txt
  new_row <- c(values,file_base_name)
  data_hub <- rbind(data_hub, new_row)

  ######<<< add part of automatically copy the readme to the corresponding server path
#      directory_path  <- as.character(file_data[24,3])
#      full_destination <- file.path(directory_path, file_base_name)
#      command <- paste0("chgrp"," ",new_group, " ", file_name)
#      system(command) ## user "shiny" is not in the group of "mbiome", so the group can not be changed, then file cann't be written to the destination 
      # Check if the directory path exists and starts with "/scratch/shire/data/nj"
#      if (file.exists(directory_path) && startsWith(directory_path, "/scratch/shire/data/nj")) {

	          # Check if the file is already in the directory path
#	          if (file.exists(full_destination)) {
#			        cat("File", file_name, "already exists in", directory_path, "\n")
#        } else {
		      # Copy the file to the directory path
#		      file.copy(file_name, full_destination)
#	      cat("File", file_name, "copied to", directory_path, "\n")
#	          }
#      } else {
#	          cat("Directory path", directory_path, "either doesn't exist or does not start with /scratch/shire/data/nj\n")
#        }
   #######>>> add part of automatically copy the readme to the corresponding server path
}

# Step 4: Write updated DataHub.txt data frame back to file
write.table(data_hub, file = "/gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/data_on_cloud/lab/DataHub.txt", sep = "\t", row.names = FALSE)

file.copy(from = "/gen/lnxdata/shiny-server/jlu/meta_template_dry_20240506/data_on_cloud/lab/DataHub.txt", to = copypath, overwrite = TRUE)

