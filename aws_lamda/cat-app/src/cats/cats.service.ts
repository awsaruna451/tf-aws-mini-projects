// src/cats/cats.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateCatDto } from '../common/dto/create-cat.dto';

export interface Cat {
  id: number;
  name: string;
  age: number;
  breed: string;
}

@Injectable()
export class CatsService {
  private cats: Cat[] = [];
  private idCounter = 1;

  create(createCatDto: CreateCatDto): Cat {
    const cat = { id: this.idCounter++, ...createCatDto };
    this.cats.push(cat);
    return cat;
  }

  findAll(): Cat[] {
    return this.cats;
  }

  findOne(id: number): Cat {
    const cat = this.cats.find((c) => c.id === id);
    if (!cat) throw new NotFoundException(`Cat #${id} not found`);
    return cat;
  }

  remove(id: number): void {
    this.cats = this.cats.filter((c) => c.id !== id);
  }
}