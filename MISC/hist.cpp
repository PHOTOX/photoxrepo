#include <stdio.h>
#include <math.h>
#include <iostream>
#include <cstdlib>
using namespace std;

const int ncolmax=10;
int  nbin=500,ncol=1,nline=0;
double begin,end;
static const char *optString = "ab:e:n:c:l:h?";
int inorm=1;  //mame histogram normovat?

int MyRound( double value )  {
	return floor( value + 0.5 );
	}

 int main(int argc, char* argv[])
 {	


int opt=0;

opt = getopt( argc, argv, optString );

while( opt != -1 ) {
    switch (opt)
      {  
         case 'a': inorm = atoi (optarg); break;
         case 'b': begin = atof (optarg); break;
         case 'e': end = atof (optarg); break;
	 case 'n': nbin = atoi (optarg); break;
	 case 'c': ncol = atoi (optarg); break;
         case 'l': nline = atoi (optarg); break;
         case '?': 
	 default : //break;
         case 'h': 
		cout << "Create histograms from columns of data." << endl;
		cout << "USAGE: hist -b 'beginning' -e end -l number-of-lines -c number-of-columns -n number-of-bins <input>output" << endl;
		cout << "OTHER OPTIONS: -a 0/1 Normovani zapnuto(default)/vypnuto" << endl;
		return 0;
		break;
      }
    opt = getopt( argc, argv, optString );
}
	if ( inorm !=1 && inorm!=0 ) cout << "Incorrect -a parameter.Use -h for help." << endl;

	double *prop[ncolmax];
	for (int i=0;i<ncol;i++) {
	 prop[i] = new double[nbin]; 
	 for (int j=0;j<nbin;j++)  prop[i][j]=0.0;
	}

	double input;
	int norm=0;
 	double bin = (end-begin)/nbin;
	int x;

//---------------------READING----------------------------------
	for (int j=0;j<nline;j++) {
		for (int i=0;i<ncol;i++) {
			cin >> input;
			x=MyRound( (input-begin)/bin );
			if ( x<nbin && x>=0 && cin.good() ) {
				norm=norm+1;
				prop[i][x]=prop[i][x]+1;
			}
			//x=-1;	//dirty hack to avoid overcounting the last x after EOF
		}
	}
//---------------------PRINTING----------------------------
	for (int i=0;i<nbin;i++) {
		cout << begin+bin*i << "\t";
		for (int j=0;j<ncol;j++) cout << prop[j][i]/norm/bin << "\t";
		cout << endl;
	}


	return 0;
}
 
