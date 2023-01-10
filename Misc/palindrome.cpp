#include <string>
#include <iostream>
using namespace std;

bool palindrome(string s){
    int i = 0;
    int j = s.length()-1;
    while (i < j){
        if (s[i] != s[j]){
            cout << "That was NOT a palindrome.";
            return false;
        } 
        else{
            i++;
            j--;
        }
    }
    cout << "That was a palindrome.";
    return true;
}

int main(){
    string s;
    cout << "enter a word: ";
    cin >> s;
    palindrome(s);
    return 0;
}