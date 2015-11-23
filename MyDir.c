#include  <windows.h>
#include  <tchar.h>
#include  <stdio.h>
#include  <string.h>

// Vrariables globales
int   formatage   = 1;
int   nbFile      = 0;
int   nbDirectory = 0;
int   i;

// prototype 
int   dir (const char *givenPath);

int dir (const char *givenPath)
{

  WIN32_FIND_DATA FindFileData;
  HANDLE hFind;
  
  char *path = malloc (sizeof(char)*(strlen(givenPath) + strlen("\\*") + 1));
  strcpy(path, givenPath);
  strcat(path,"\\*");
  
  hFind      = FindFirstFile(path, &FindFileData);
  
  if (hFind  == INVALID_HANDLE_VALUE){
    
    printf ("FindFirstFile error (%d)\n", GetLastError());
    return;
  
  }else{    
    do{
      if  (FindFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY){
        printf ("|");
        for (i = 0; i < formatage; i++){
          printf("-");
        }

        printf (TEXT(" <DIR> %6s\n"), FindFileData.cFileName);

          if (strcmp((char*)FindFileData.cFileName,".") == 1){
            
            if (strcmp(FindFileData.cFileName,"..") == 1){
            
            nbDirectory   = nbDirectory + 1;
            // On va chercher recursivement le contenus des autres dossiers
            char *tmp_dir = malloc (sizeof(char)*(strlen(givenPath) + strlen(FindFileData.cFileName)+ 2));  
            strcpy(tmp_dir, givenPath);
            strcat(tmp_dir,"\\");
            strcat(tmp_dir,FindFileData.cFileName);
            formatage     = formatage + 3;
            // recursivité
            dir (tmp_dir);
            formatage     = formatage - 3;
            free (tmp_dir);
            
            }
          }
      }else{

        nbFile = nbFile + 1;
        printf ("|");
        
        for (i = 0; i < formatage; i++){
          printf("-");
        }

    
        printf (TEXT(" <FILE> %5s\n"),FindFileData.cFileName);    
        
      }
    } while (FindNextFile(hFind, &FindFileData) != 0);        
  
  }
  
  free(path);
}


int main (int argc, char **argv){

  dir("C:\\Users");

  printf ("Number of directory found:  %d\n",nbDirectory) ;
  printf ("Number of files found    :  %d\n",nbFile) ;
  system ("pause");

}