#Assembleur IA32

## Projet "MyDir"

### 1 Consigne
>Développez une fonction de recherche et d'affichage de tous fichiers contenus sur le disque à partir d'un chemin fourni par l'utilisateur. Votre programme devra, par conséquent, être capable de parcourir toute l'arborescence à partir du point d'entré fourni par l'utilisateur. 

### 2 Problématique

L'objectif de ce TP est de nous sensibiliser à la programmation en ASM (MASM32 plus exactement) et à la lecture de code assembleur.  
 
#### 2.1 Analyse théorique
Le listing d'un dossier et de ces sous dossiers est simplifié sous Windows grâce à l'API du même nom. 
Cette API nous décharge d'une grande partie de gestion des erreurs et différents accès système. 

Pseudo code de "MyDir" :
```bat
    PathToScan == UserPathInput
    FindFirstFile in UserPathInput
        There is a first file ?        continue : GOTO leave
        FindFirstFile is a directory ? continue : GOTO printFileName
        is directory "." or ".."       GOTO findNextFile : continue 
        PathToScan = PathToScan + DirName
        Goto FindFirstFile
    printFileName : 
        print File name & GOTO findNextFile
    findNextFile:
        There is a Next file ?          continue : GOTO leave
        is directory "." or ".."       GOTO findNextFile : continue 
        PathToScan = PathToScan + DirName
        print File name
        Goto FindFirstFile
    leave : 
        free variable
        ret
```
Ceci est une approche récursive naïve du listing de fichiers

Les difficultés liés à ce code sont : 
*   La gestion de la variable path qui varient en fonction de la profondeur
*   Gérer la remonter dans les dossiers parents
*   Intéragir avec l'utilisateur 

#### 2.2 Implémentation C
Suite à des soucis d'ordre technique (problème sur les machines universitaires) je n'ai eu que peut de temps pour re-réaliser mon code. 
Cette version ne gère pas l'input utilisateur. 
Le chemin absolu du répertoire à lister est en dur dans le fichier. 

Analyse des parties essentielles :  
* La structure [WIN32_FIND_DATA](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365740%28v=vs.85%29.aspx)
```c
 WIN32_FIND_DATA FindFileData; // Déclaration de la strcuture   
  /* some code */
  strcmp((char*)FindFileData.cFileName,"." //Comparaison d'un attribut du fichier
```
Cette structure stocke l'ensemble des attributs disponnibles pour un fichier. Elle permet de récupérer la taille, le type, le nom, etc.

* Gestion des erreurs : 
```c
if (hFind  == INVALID_HANDLE_VALUE){ // Si la lecture c'est mal passée 
    printf ("FindFirstFile error (%d)\n", GetLastError()); // On récupère l'erreur et on l'affiche
    return;
}
```
Durant ce projet je n'ai pas eu le temps de gérer correctement les apparitions d'erreurs et les exceptions. Mais c'est une piste possible d'amélioration

* Concaténation des paths
Pour lister correctement un dossier l'API windows demande un chemin (absolu de preférence) qui ce termine par un "\", comme il s'agit d'un caractère il faut l'échapper lui même: "\\\".
```c
// Allocation de la mémoire 
char *tmp_dir = malloc (sizeof(char)*(strlen(givenPath) + strlen(FindFileData.cFileName)+ 2));  
            strcpy(tmp_dir, givenPath); // On copie le path dans la variable tmp
            strcat(tmp_dir,"\\");       // On concatène
            strcat(tmp_dir,FindFileData.cFileName); // On rajoute le nom de fichier
            dir   (tmp_dir); //Recursivité avec le nouveau path
```

Le code complet est disponnible en annexe.

#### 2.3 Implémentation MASM

C'est sur cette partie que j'ai passé le plus de temps.
* Listing et récurisivité 
```asm
;----------------------------------------------------------------------------;
;                           Find function entry                              ;
;----------------------------------------------------------------------------;
; This recursive function is the core of this program. It take in entry the  ;
; ptr of the path to browse                                                  ;
;----------------------------------------------------------------------------;
    Find    proc    myPath:PTR BYTE
            ; Local WFD structure 
            LOCAL structFindData : WIN32_FIND_DATA
            push    esi ; used for myPath
            push    edi ; used for hFile HANDLE
            mov     esi, myPath ; push myPath into the stack 
            /*----snipped code----*/
            push    esi
            call    lstrlen
            lea     eax,[esi + eax] ; myPath + strlen(myPath)
            ;; invoke  Find, eax 
            push    eax
            call    Find      ; Recursive loop 
```
Ici on peut voir comment ce fait l'appel à la récursivité avec une allocation dynamique de la taille de l'argument en fonction de la longueur du path et du nom de fichier à ajouter.  La récursivité empilant les push dans la _stack_ il faut absolument pop les registres utilisé en quitant la fonction (pour chaque niveau de profondeur), comme ci dessous.
```asm
    ; Exit and error routine 
    funError:
            ; free register and leave the current loop
            pop     edi ; File Handle
            pop     esi ; myPath
            ret
    Find    end
```
Pour ce code assembleur j'ai genéré une interface GUI qui permet à l'user de rentrer un input puis liste les fichiers quand un clic est réalisé.
Une autre partie intéressante est la création d'une fenêtre d'edition multiligne (comprendre, où l'on écrit plusieurs lignes les unes en dessous des autres).
```asm 
;----------------------------------------------------------------------------;
;                           Create dir listing windows                       ;
;----------------------------------------------------------------------------;
    ;invoke CreateWindowEx,WS_EX_CLIENTEDGE, NULL,NULL,\
    ;                WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or\
    ;                ES_AUTOHSCROLL or WS_HSCROLL or WS_VSCROLL or \
    ;                ES_MULTILINE or ES_READONLY ,\
    ;                20,100,735,305,hWnd,EditID,hInstance,NULL
    push    NULL
    push    hInstance
    push    EditID
    push    hWnd
    push    305
    push    735
    push    100
    push    20
    push    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or\
            ES_AUTOHSCROLL or WS_HSCROLL or WS_VSCROLL or \
            ES_MULTILINE or ES_READONLY ;ES_MULTILIGNE pour l
affichage multi lige
    push    NULL
    push    offset EditClassName
    push    WS_EX_CLIENTEDGE
    call    CreateWindowEx
    mov     hwndPrint,  eax ; Save unique window ID

```

### 3 Conclusion

#### 3.1 Visuellement
C version :
![](http://i.imgur.com/W9cJYrF.png)

MASM version : 
![](http://i.imgur.com/m2mdeTv.png)

#### 3.2 Ressentie

Dans un premier temps, le passage par le C ma semblé n'être qu'une perte de temps, alors je me suis empressé de passer à l'assembleur.
Avec le recul et les heures passé à débuguer mon programme, je pense que je passerais plus de temps sur le C (création du GUI et gestion des erreurs), afin de réaliser l'assembleur plus rapidement.

Je regrette un peu l'utilisation de MASM32 qui finalement n'est pas si loin des langages haut niveau (présence de while, if, etc.). Nous ne faisons pas du vrais assembleur système et en utilisant ollydbg, on ce rend bien compte que notre code est recompilé par la machine.

Pour débuguer j'ai parfois été enmené à utiliser ollydbg et même si il semble très puissant, ce logiciel est dificile à prendre en main et quelques heures de cours sur son utilisation seraient les bienvenus. 

Globalement c'est un bon projet, formateur et gratifiant.

