#include <stdio.h>
#include <windows.h>
#include <winuser.h>

void SendKey(WORD keyCode, int mode) {
  INPUT input = { 0 };
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = keyCode;

  switch (mode) {
    case 0:
      input.ki.dwFlags = KEYEVENTF_KEYUP;
      SendInput(1, &input, sizeof(INPUT));
      break;
    case 1:
      SendInput(1, &input, sizeof(INPUT));
      break;
    case 2:
      SendInput(1, &input, sizeof(INPUT)); 
      input.ki.dwFlags = KEYEVENTF_KEYUP;
      SendInput(1, &input, sizeof(INPUT)); 
      break;
  }
}

int toggle = 0;
void SendKeystrokesToWindow(HWND hwnd, int* tog) {
  int delay = 14;
  if (hwnd != NULL) {
    switch(*tog) {
      case 0:
        SetForegroundWindow(hwnd);
        SendKey(VK_CONTROL, 1);
        for (int i=0; i<6; i++) { SendKey(VK_OEM_MINUS, 2); Sleep(delay-i); }
        SendKey(VK_CONTROL, 0); Sleep(100);
      break;
      case 1:
        SetForegroundWindow(hwnd);
        SendKey(VK_CONTROL, 1);
        for (int i=0; i<6; i++) { SendKey(VK_OEM_PLUS, 2); Sleep(delay-i); }
        SendKey(VK_CONTROL, 0); Sleep(100);
      break;
    } *tog = !(*tog);
  }
}

void SendJumpStrokes(HWND hwnd, int dir, int alt) {
  int delay = 8;
  int jumps = 6+alt*10;
  if (hwnd != NULL) {
    switch(dir) {
      case 0: // down
        SetForegroundWindow(hwnd); //Sleep(100);
        SendKey(VK_CONTROL, 0);
        for (int i=0; i<jumps; i++) {
          SendKey(74, 2);
          SendKey(90, 2);
          SendKey(90, 2);
          if (i!=jumps-1) {Sleep(delay);}
        }
        SendKey(VK_CONTROL, 1);
        break;
      case 1: // up
        SetForegroundWindow(hwnd); //Sleep(100);
        SendKey(VK_CONTROL, 0);
        for (int i=0; i<jumps; i++) {
          SendKey(75, 2);
          SendKey(90, 2);
          SendKey(90, 2);
          if (i!=jumps-1) {Sleep(delay);}
        }
        SendKey(VK_CONTROL, 1);
        break;
    }
  }
}

char currentTitle[256];

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    HWND hWnd = GetConsoleWindow();
    if (hWnd != NULL) {
        ShowWindow(hWnd, SW_HIDE);
    }

  while (1) {
    if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) && (GetAsyncKeyState(VK_SPACE) & 0x8000)) {

      GetWindowText(GetForegroundWindow(), currentTitle, sizeof(currentTitle));
      if (strcmp(currentTitle, "Terminal") == 0) {
        SendKeystrokesToWindow(GetForegroundWindow(), &toggle);
      }
      // Sleep(100);
    }

    if (GetAsyncKeyState(VK_CONTROL) && (GetAsyncKeyState(75) & 0x8000)) {

      GetWindowText(GetForegroundWindow(), currentTitle, sizeof(currentTitle));
      if (strcmp(currentTitle, "Terminal") == 0) {
        SendJumpStrokes(GetForegroundWindow(), 1, 0);
      }
    }

    if (toggle && (GetAsyncKeyState(75) & 0x8000)) {

      GetWindowText(GetForegroundWindow(), currentTitle, sizeof(currentTitle));
      if (strcmp(currentTitle, "Terminal") == 0) {
        SendJumpStrokes(GetForegroundWindow(), 1, 1);
      }
    }

    if (GetAsyncKeyState(VK_CONTROL) && (GetAsyncKeyState(74) & 0x8000)) {

      GetWindowText(GetForegroundWindow(), currentTitle, sizeof(currentTitle));
      if (strcmp(currentTitle, "Terminal") == 0) {
        SendJumpStrokes(GetForegroundWindow(), 0, 0);
      }
    }

    if (toggle && (GetAsyncKeyState(74) & 0x8000)) {

      GetWindowText(GetForegroundWindow(), currentTitle, sizeof(currentTitle));
      if (strcmp(currentTitle, "Terminal") == 0) {
        SendJumpStrokes(GetForegroundWindow(), 0, 1);
      }
    }

    if (GetAsyncKeyState(VK_F9) & 0x8000) {exit(0);}
  }

  return 0;
}


  // const unsigned long t_pid = strtoul(argv[1], NULL, 10);
  // int threadIdInt = (int)threadId;
  // int argvInt = atoi(argv[2]);
  // printf("new:  %i   %i\n",threadIdInt, argvInt);
  // printf("%lu\n",threadId);
