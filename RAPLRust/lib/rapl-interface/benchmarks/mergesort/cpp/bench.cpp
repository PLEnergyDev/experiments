#include <iostream>
#include <fstream>
#include <sstream>

using namespace std;
extern "C" {
    void start_rapl();
    void stop_rapl();
}

#include <iterator>
#include <algorithm>
#include <functional> 
#include <string>
#include <vector>


// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Rosetta code start
template<typename RandomAccessIterator, typename Order>
 void mergesort(RandomAccessIterator first, RandomAccessIterator last, Order order)
{
  if (last - first > 1)
  {
    RandomAccessIterator middle = first + (last - first) / 2;
    mergesort(first, middle, order);
    mergesort(middle, last, order);
    std::inplace_merge(first, middle, last, order);
  }
}

template<typename RandomAccessIterator>
 void mergesort(RandomAccessIterator first, RandomAccessIterator last)
{
  mergesort(first, last, std::less<typename std::iterator_traits<RandomAccessIterator>::value_type>());
}

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Rosetta code stop

// read a vector from a string, inspired by secound answer of https://stackoverflow.com/questions/14265581/parse-split-a-string-in-c-using-string-delimiter-standard-c
vector<int> IntVectorFromString(std::string str){
  vector<int> result;
  std::stringstream ss (str);
  std::string item;

  while (getline(ss, item, ',')) {
    result.push_back(std::atoi(item.c_str()));
  }

  return result;
}

// function for reading file, inspired by https://www.w3schools.com/cpp/cpp_files.asp
std::string readFile(std::string path){
  ifstream file(path);
  std::string str;

  while (getline(file, str)) {
    // do nothing
  }
  file.close();

  return str;
}

int main(int argc, char *argv[]) {

    std::string mergeParamRaw = readFile(argv[2]);

    // removing brackets
    mergeParamRaw.erase(remove(mergeParamRaw.begin(), mergeParamRaw.end(), ']'), mergeParamRaw.end());
    mergeParamRaw.erase(remove(mergeParamRaw.begin(), mergeParamRaw.end(), '['), mergeParamRaw.end());

    // getting numbers from mergeParamRaw
    vector<int> mergeParam = IntVectorFromString(mergeParamRaw);

    int count = std::atoi(argv[1]);

    for (int i = 0; i < count; i++) {
        // copying mergeParam to avoid changing it
        vector<int> mergeParamCopy = vector<int>(mergeParam);

        start_rapl();

        mergesort(mergeParamCopy.begin(), mergeParamCopy.end());

        stop_rapl();

        // stopping compiler optimization
        if (mergeParamCopy.size() < 42){
            for (int i = 0; i < mergeParamCopy.size(); i++){
                std::cout << mergeParamCopy[i] << " ";
            }
            std::cout << std::endl;
        }
    }

    return 0;
}
