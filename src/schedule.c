
int RunningTask = 0;
int LeftTicks[] = {0, 0, 0, 0};
int TaskPriority[] = {8, 6, 4, 2};

int main()
{
    if(LeftTicks[RunningTask] == 0)
    {
        if(LeftTicks[0] == 0 && LeftTicks[1] == 0 && LeftTicks[2] == 0 && LeftTicks[3] == 0)
        {
            for(int i = 0; i<4; i++)
            {
                LeftTicks[i] = TaskPriority[i];
            }
        }
        int max = 0;
        for(int i = 0; i<4; i++)
        {
            if(LeftTicks[i] > max)
            {
                max = TaskPriority[i];
                RunningTask = i;
            }
        }
        
    }
    LeftTicks[RunningTask]--;
}

