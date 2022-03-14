#include <cstdint>
extern "C" int Print(const char *str, ...);

int main()
{
	int a = -999;
	int b = 0xFFF;
	const char word[] = "?|?|?|?|?|?";

	Print("___%d___%x___%%___%o___%s___%d___%d___%c\n", 
			a, b, 10, word, 12, 13, 'P');

	Print("sdkfjslkjfl%ddsfas\n", a);
	return 0;
}
