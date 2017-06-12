/* 	Author Mateusz Wasiak
   	INTEL ARKO Project
	MAXIMAL FILTER
*/

#include<stdio.h>
#include<allegro.h>

#ifdef _cplusplus
extern "C" {
#endif
 int func(char *inMemory, char *outMemory, int width, int height, int n);
#ifdef _cplusplus
}
#endif



int main(int argc, char **argv)
{
	FILE *in;
	FILE *out;

	char* inName ;
	char outName[100];
	char toRead[4];

    int i=0;
	int j=0;
	int k=0;

	unsigned int padding;
	unsigned int onset;
	unsigned int offset;
	unsigned int width;
	unsigned int height;

	char *inMemory;
	char *outMemory;

	int returned;
	int val;
	int flag=1;
    int trueIfIn=1;
	int n;
	
	if (argc == 3)
	{
		inName = argv[1];
		n = atoi(argv[2]);
		
	}
	else
	{
	char iName[100] ;
	printf("Podaj nazwe pliku wejsciowego: ");
    scanf("%s", iName);
	inName = iName;
	printf("Podaj rozmiar maski: ");
	scanf("%d", &n);
    	}
	if ((in=fopen(inName, "rb"))==NULL)
    {
        printf ("Błąd otwarcia pliku: %s!\n",inName);
        return 1;
    }
	
	printf("Rozmiar maski: %d\n", n);

    fseek(in, 2, 0);
    fread(toRead, 1, 4, in);    // wczytanie ilości bajtow pliku
    onset = *(unsigned int *)toRead;
    printf("Onset: %d\n", onset);

    fseek(in, 10, 0);
    fread(toRead, 1, 4, in);    // wczytanie offset-u
    offset = *(unsigned int *)toRead;
    printf("Offset: %d\n", offset);

    fseek(in, 18, 0);
   	fread(toRead, 1, 4, in);    // wczytanie szerokosci-u
    width = *(unsigned int *)toRead;
    printf("Width: %d\n", width);

    fseek(in, 22, 0);
    fread(toRead, 1, 4, in);    // wczytanie wysokosci-u
    height = *(unsigned int *)toRead;
    printf("Height: %d\n", height);

    padding = (width*3)%4;
	if(padding!=0)
		padding = 4 - padding;

    inMemory =  malloc(onset * sizeof(char));
    outMemory = malloc(onset * sizeof(char));
	
	
    fseek(in, 0, 0);
    fread(inMemory, 1, onset, in);

	returned=func(inMemory, outMemory, width, height, n);

    fclose(in);

	BITMAP* outBMP;
	BITMAP* inBMP;

	allegro_init();
	install_keyboard();
	set_color_depth(24);
	set_gfx_mode( GFX_AUTODETECT_WINDOWED,width*2+50,height, 0, 0);

	inBMP = create_bitmap(width, height);
	if (!inBMP)
        	{
		printf("Couldn't load lara.bmp!\n");
		return 1;
		}
	outBMP = create_bitmap(width, height);
	if (!outBMP)
        	{
		printf("Couldn't load out.bmp!\n");
		return 1;
		}

	i=height-1;
	j=0;
	while(i>=0)
	{
		k=0;
		while(k<width*3)
		{
            outBMP->line[i][k]=*(outMemory+offset+j*(width*3+padding)+k);
            ++k;
		}
		--i;
		++j;
	}

	i=height-1;
	j=0;
	while(i>=0)
	{
		k=0;
		while(k<width*3)
		{
            inBMP->line[i][k]=*(inMemory+offset+j*(width*3+padding)+k);
            ++k;
		}
		--i;
		++j;
	}

	blit(outBMP, screen, 0,0,width+50,0,width, height);

    while (1)
    {
        switch (flag)
        {
            case 1:
                blit(inBMP, screen, 0,0,0,0,width, height);
                break;

            case 2:
				flag =1;
                if(trueIfIn)
                {
                    returned=func(outMemory, inMemory, width, height,n);
                    trueIfIn = 0;
                }
                else
                {
                    returned=func(inMemory, outMemory, width, height,n);
                    trueIfIn = 1;
                }

                i=height-1;
                j=0;
                while(i>=0)
                {
                    k=0;
                    while(k<width*3)
                    {
                        outBMP->line[i][k]=*(inMemory+offset+j*(width*3+padding)+k);
                        ++k;
                    }
                    --i;
                    ++j;
                }
                blit(outBMP, screen, 0,0,width+50,0,width, height);
                break;

        }

        val = readkey();

        if ((val >> 8) == KEY_ENTER) 
            flag =2;


        if ((val >> 8) == KEY_ESC) 
             break;

       
    }

    destroy_bitmap(inBMP);
    destroy_bitmap(outBMP);
    allegro_exit();

	

	free(inMemory);
   	free(outMemory);

	return 0;
}
