#include<iostream>

using namespace std;
#define sa 256
#define ss 16
int area[sa];
int area2[sa];

int mod(int i,int k){
  k = i - i / k * k;
  return k;
}
int conv(int x,int y){
  return mod(x + y * ss,sa);
}

int isvalue(int x,int y){
  return 0 <= x && x < ss && 0 <= y && y < ss;
}

void game(int i){
  int c = 0;
  int x = mod(i,ss),y = i / ss;
  for(int j = -1; j <= 1;++j){
    for(int k = -1; k <= 1;++k){
      if(isvalue(x+j,y+k) && area[conv(x+j,y+k)]) ++c;
    }
  }
  if(area[i]){
    if(c == 2 || c == 3){
      area2[i] = 1;
    }
    else area2[i] = 0;
  }
  else{
    if(c == 3) area2[i] = 1;
  }
}

int main(){
  char c;
  for(int i = 0; i < sa;++i){
    cin >> c;
    area[i] = c-'0';
  }
  while(1){
    cout << endl;
    for(int i = 0;i < ss;++i){
      for(int j = 0; j < ss;++j){
        cout << area[conv(j,i)];
      }
      cout << endl;
    }
    getchar();
    for(int i = 0; i < sa;++i){
      game(i);
    }
    for(int i = 0; i < sa;++i){
      area[i] = area2[i];
    }
  }
  return 0;
}


