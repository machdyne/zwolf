uint8_t zw_read8(uint16_t addr);
void zw_write8(uint16_t addr, uint8_t data);
uint8_t zw_io_load(uint8_t port);
void zw_io_store(uint8_t port, uint8_t data);
int zw_getchar();
void zw_putchar(char c);
